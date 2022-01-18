import styled from "styled-components";

export const ColorCard = styled.div`
  width: 100px;
  height: 100px;
  background-color: ${props => props.color};
  border-radius: 5px;
`;
